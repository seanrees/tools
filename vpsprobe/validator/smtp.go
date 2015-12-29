package validator

import (
	"bytes"
	"fmt"
	"net/smtp"
	"os"
	"strings"
)

func ValidateSMTP(server string, from string, to string, send bool) (bool, error) {
	serverport := []string{server, ""}
	if !strings.Contains(server, ":") {
		serverport[1] = ":25"
	}

	server = strings.Join(serverport, "")

	hostname, err := os.Hostname()
	if err != nil {
		return false, err
	}

	message := bytes.NewBufferString("")
	message.WriteString(
		fmt.Sprintf("Subject: test message from %s\r\n\r\n", hostname))
	message.WriteString("This is a test message. Parameters:\r\n")
	message.WriteString(fmt.Sprintf("  hostname=%s\r\n", hostname))
	message.WriteString(fmt.Sprintf("  server=%s\r\n", server))
	message.WriteString(fmt.Sprintf("  to=%s\r\n", to))
	message.WriteString(fmt.Sprintf("  from=%s\r\n", from))
	message.WriteString("\r\nIf you see this, the test likely succeeded.")

	client, err := smtp.Dial(server)
	if err != nil {
		return false, err
	}
	if err = client.Hello(hostname); err != nil {
		return false, err
	}
	client.Mail(from)
	client.Rcpt(to)
	if send {
		writer, err := client.Data()
		if err != nil {
			return false, err
		}
		defer writer.Close()
		if _, err = message.WriteTo(writer); err != nil {
			return false, err
		}
	}
	client.Quit()
	return true, nil
}
