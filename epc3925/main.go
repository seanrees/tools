// Binary rebootepc triggers a reboot of a Cisco EPC3925 cable modem through the
// modem's HTTP interface.
package main

import (
	"flag"
	"fmt"
	"log"
	"net/http"
	"net/url"
	"strings"
)

var (
	host     = flag.String("host", "", "Host/IP to cable modem")
	password = flag.String("password", "", "Password of cable modem")
	username = flag.String("username", "admin", "Username of cable modem")
	debug    = flag.Bool("debug", false, "Write debug information to log")
)

func debugf(format string, v ...interface{}) {
	if *debug {
		log.Printf(format, v...)
	}
}

type modem struct {
	host, username, password string
}

func (m *modem) login() (string, error) {
	path := fmt.Sprintf("http://%s/goform/Docsis_system", m.host)
	args := url.Values{
		"username_login": {m.username},
		"password_login": {m.password},
	}
	resp, err := http.PostForm(path, args)
	if err != nil {
		return "", err
	}

	for _, c := range resp.Header["Set-Cookie"] {
		parts := strings.Split(c, "=")
		if parts[0] == "SessionID" {
			return c, nil
		}
	}
	return "", fmt.Errorf("no SessionID cookie found")
}

func (m *modem) reboot(sessionId string) error {
	path := fmt.Sprintf("http://%s/goform/Devicerestart", m.host)
	args := url.Values{"devicerestart": {"1"}}
	req, err := http.NewRequest("POST", path, strings.NewReader(args.Encode()))
	if err != nil {
		return err
	}
	req.Header.Set("Cookie", sessionId)
	req.Header.Set("Content-Type", "application/x-www-form-urlencoded")

	c := http.Client{}
	var resp *http.Response
	resp, err = c.Do(req)
	if err != nil {
		return err
	}
	if got, want := resp.StatusCode, 200; got != want {
		return fmt.Errorf("incorrect status, got %d want %d", got, want)
	}
	debugf("reboot response = %s", resp.Status)

	return nil
}

func main() {
	flag.Parse()

	m := &modem{
		host:     *host,
		username: *username,
		password: *password,
	}
	token, err := m.login()
	if err != nil {
		log.Fatalf("Could not login to modem: %s", err)
	}
	debugf("token = %s", token)

	if err = m.reboot(token); err != nil {
		log.Fatalf("Could not reboot modem: %s", err)
	}
	log.Printf("Reboot command delivered to %v", m.host)
}
