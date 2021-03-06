package main

import (
	"bytes"
	"flag"
	"fmt"
	"log"
	"net/smtp"
	"os"
	"strings"
)

func main() {
	server := flag.String("server", "mx1.dreamfire.net", "MX to test")
	from := flag.String("from", "sean@erifax.org", "From address")
	to := flag.String("to", "srees@dreamfiresolutions.com", "To address")
	silent := flag.Bool("silent", true, "Run in silent mode")
	send := flag.Bool("send", false, "Actually send a message")

	flag.Parse()

	serverport := []string{*server, ""}
	if !strings.Contains(*server, ":") {
		serverport[1] = ":25"
	}

	*server = strings.Join(serverport, "")
	if !*silent {
		log.Printf("server=%s, from=%s, to=%s", *server, *from, *to)
	}

	hostname, err := os.Hostname()
	if err != nil {
		log.Fatal(err)
	}

	message := bytes.NewBufferString("")
	message.WriteString(
		fmt.Sprintf("Subject: test message from %s\r\n\r\n", hostname))
	message.WriteString("This is a test message. Parameters:\r\n")
	message.WriteString(fmt.Sprintf("  hostname=%s\r\n", hostname))
	message.WriteString(fmt.Sprintf("  server=%s\r\n", *server))
	message.WriteString(fmt.Sprintf("  to=%s\r\n", *to))
	message.WriteString(fmt.Sprintf("  from=%s\r\n", *from))
	message.WriteString("\r\nIf you see this, the test likely succeeded.")

	client, err := smtp.Dial(*server)
	if err != nil {
		log.Fatal(err)
	}
	if err = client.Hello(hostname); err != nil {
		log.Fatal(err)
	}
	client.Mail(*from)
	client.Rcpt(*to)
	if *send {
		writer, err := client.Data()
		if err != nil {
			log.Fatal(err)
		}
		defer writer.Close()
		if _, err = message.WriteTo(writer); err != nil {
			log.Fatal(err)
		}
	}
	client.Quit()
}
