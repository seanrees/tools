// Command vpsprobe provides a combined HTTP and SMTP prober.
package main

import (
	"flag"
	"log"
	"os"

	"github.com/seanrees/tools/vpsprobe/validator"
)

// Flag Variables
var silent bool

type SmtpOptions struct {
	enable bool
	server string
	from   string
	to     string
	doSend bool
}

var smtpOpts = SmtpOptions{}

type HttpOptions struct {
	enable bool
	server string
	url    string
	code   int
}

var httpOpts = HttpOptions{}

func init() {
	flag.BoolVar(&silent, "silent", true, "run silently")

	flag.BoolVar(&smtpOpts.enable, "smtp", true, "do smtp check")
	flag.StringVar(&smtpOpts.server, "smtp_server", "", "smtp server")
	flag.StringVar(&smtpOpts.from, "smtp_from", "", "from address")
	flag.StringVar(&smtpOpts.to, "smtp_to", "", "to address")
	flag.BoolVar(&smtpOpts.doSend, "smtp_send", false, "send test message")

	flag.BoolVar(&httpOpts.enable, "http", true, "do http check")
	flag.StringVar(&httpOpts.server, "http_server", "", "http server")
	flag.StringVar(&httpOpts.url, "http_url", "", "url to test")
	flag.IntVar(&httpOpts.code, "http_code", 200, "expected return code")
}

func Log(format string, v ...interface{}) {
	if !silent {
		log.Printf(format, v...)
	}
}

func doSMTP(c chan bool) {
	if smtpOpts.enable {
		Log("SMTP enabled, server=%s", smtpOpts.server)
		res, err := validator.ValidateSMTP(
			smtpOpts.server, smtpOpts.from, smtpOpts.to, smtpOpts.doSend)
		if err != nil {
			log.Printf("%s", err)
		}
		c <- res
	} else {
		// Not enabled, just return true.
		c <- true
	}
}

func doHTTP(c chan bool) {
	if httpOpts.enable {
		Log("HTTP enabled, server=%s, url=%s", httpOpts.server, httpOpts.url)
		res, err := validator.ValidateHTTP(
			httpOpts.server, httpOpts.url, httpOpts.code)
		if err != nil {
			log.Printf("%s", err)
		}
		c <- res
	} else {
		// Not enabled, just return true.
		c <- true
	}
}

func main() {
	flag.Parse()

	smtpChan := make(chan bool)
	httpChan := make(chan bool)

	go doSMTP(smtpChan)
	go doHTTP(httpChan)

	if !<-smtpChan || !<-httpChan {
		log.Printf("host tested = %s", smtpOpts.server)
		os.Exit(1)
	}
}
