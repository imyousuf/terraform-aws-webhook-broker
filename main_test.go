package main

import (
	"bytes"
	"fmt"
	"io/ioutil"
	"log"
	"net"
	"net/http"
	"os"
	"path/filepath"
	"testing"
	"time"

	"github.com/imyousuf/webhook-broker/controllers"
	"github.com/stretchr/testify/assert"
)

func TestGetAppVersion(t *testing.T) {
	assert.Equal(t, string(GetAppVersion()), "0.1-dev")
}

var mainFunctionBreaker = func(stop *chan os.Signal) {
	go func() {
		var client = &http.Client{Timeout: time.Second * 10}
		defer func() {
			client.CloseIdleConnections()
		}()
		for {
			response, err := client.Get("http://localhost:8080/_status")
			if err == nil {
				if response.StatusCode == 200 {
					break
				}
			}
		}
		fmt.Println("Interrupt sent")
		*stop <- os.Interrupt
	}()
}

var panicExit = func(code int) {
	panic(code)
}

func TestMainFunc(t *testing.T) {
	t.Run("SuccessRun", func(t *testing.T) {
		var buf bytes.Buffer
		log.SetOutput(&buf)
		oldArgs := os.Args
		os.Args = []string{"webhook-broker"}
		oldNotify := controllers.NotifyOnInterrupt
		controllers.NotifyOnInterrupt = mainFunctionBreaker
		defer func() {
			log.SetOutput(os.Stderr)
			os.Args = oldArgs
			controllers.NotifyOnInterrupt = oldNotify
		}()
		main()
		logString := buf.String()
		assert.Contains(t, logString, "Webhook Broker")
		assert.Contains(t, logString, string(GetAppVersion()))
		t.Log(logString)
	})
	t.Run("HelpError", func(t *testing.T) {
		oldExit := exit
		oldArgs := os.Args
		oldConsole := consolePrintln
		exit = panicExit
		consolePrintln = func(output string) {
			assert.Contains(t, output, "Usage of")
			assert.Contains(t, output, "-config")
			assert.Contains(t, output, "-migrate")
		}
		os.Args = []string{"webhook-broker", "-h"}
		func() {
			defer func() {
				if r := recover(); r != nil {
					assert.Equal(t, 1, r.(int))
				}
			}()
			main()
		}()
		defer func() {
			exit = oldExit
			os.Args = oldArgs
			consolePrintln = oldConsole
		}()
	})
	t.Run("ParseError", func(t *testing.T) {
		oldExit := exit
		oldArgs := os.Args
		exit = panicExit
		os.Args = []string{"webhook-broker", "-migrate1=test"}
		func() {
			defer func() {
				if r := recover(); r != nil {
					assert.Equal(t, 1, r.(int))
				}
			}()
			main()
		}()
		defer func() {
			exit = oldExit
			os.Args = oldArgs
		}()
	})
	t.Run("ConfError", func(t *testing.T) {
		ln, netErr := net.Listen("tcp", ":8080")
		if netErr == nil {
			defer ln.Close()
			oldExit := exit
			oldArgs := os.Args
			exit = panicExit
			os.Args = []string{"webhook-broker"}
			func() {
				defer func() {
					if r := recover(); r != nil {
						assert.Equal(t, 3, r.(int))
					}
				}()
				main()
			}()
			defer func() {
				exit = oldExit
				os.Args = oldArgs
			}()
		}
	})
}

func TestParseArgs(t *testing.T) {
	absPath, _ := filepath.Abs("./migration")
	t.Run("FlagParseError", func(t *testing.T) {
		t.Parallel()
		_, _, err := parseArgs("webhook-broker", []string{"-migrate1", "no such path"})
		assert.NotNil(t, err)
	})
	t.Run("NonExistentMigrationSource", func(t *testing.T) {
		t.Parallel()
		_, _, err := parseArgs("webhook-broker", []string{"-migrate", "no such path"})
		assert.NotNil(t, err)
	})
	t.Run("MigrationSourceNotDir", func(t *testing.T) {
		t.Parallel()
		_, _, err := parseArgs("webhook-broker", []string{"-migrate", "./LICENSE"})
		assert.NotNil(t, err)
		assert.Equal(t, err, ErrMigrationSrcNotDir)
	})
	t.Run("ValidMigrationSourceAbs", func(t *testing.T) {
		t.Parallel()
		cliConfig, _, err := parseArgs("webhook-broker", []string{"-migrate", "./migration"})
		assert.Nil(t, err)
		assert.True(t, cliConfig.IsMigrationEnabled())
		assert.Equal(t, "file://"+absPath, cliConfig.MigrationSource)
	})
	t.Run("ValidMigrationSourceRelative", func(t *testing.T) {
		t.Parallel()
		cliConfig, _, err := parseArgs("webhook-broker", []string{"-migrate", absPath})
		assert.Nil(t, err)
		assert.True(t, cliConfig.IsMigrationEnabled())
		assert.Equal(t, "file://"+absPath, cliConfig.MigrationSource)
	})
}

const testLogFile = "./log-setup-test-output.log"

type MockLogConfig struct {
	// Filename:   config.GetLogFilename(),
	// 		MaxSize:    int(config.GetMaxLogFileSize()), // megabytes
	// 		MaxBackups: int(config.GetMaxLogBackups()),
	// 		MaxAge:     int(config.GetMaxAgeForALogFile()),        //days
	// 		Compress:   config.IsCompressionEnabledOnLogBackups(), // disabled by default
}

func (m MockLogConfig) GetLogFilename() string                 { return testLogFile }
func (m MockLogConfig) GetMaxLogFileSize() uint                { return 10 }
func (m MockLogConfig) GetMaxLogBackups() uint                 { return 1 }
func (m MockLogConfig) GetMaxAgeForALogFile() uint             { return 1 }
func (m MockLogConfig) IsCompressionEnabledOnLogBackups() bool { return true }
func (m MockLogConfig) IsLoggerConfigAvailable() bool          { return true }

func TestSetupLog(t *testing.T) {
	_, err := os.Stat("./log-setup-test-output.log")
	if err == nil {
		os.Remove(testLogFile)
	}
	setupLogger(&MockLogConfig{})
	log.Println("unit test")
	dat, err := ioutil.ReadFile(testLogFile)
	assert.Nil(t, err)
	assert.Contains(t, string(dat), "unit test")
}
