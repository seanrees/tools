// Command denon provides a simple CLI to control the Denon AVR1912
//
// This may control other AVRs from Marantz/Denon.
// API documentation:
// http://www.procinema.hu/dokumentumok/denon-avr-1912-protokoll.pdf
//

package main

import (
	"bufio"
	"flag"
	"fmt"
	"net"
	"strconv"
	"strings"
	"time"
)

var (
	denonAddress = flag.String("address", "denon", "Host or IP of Denon receiver.")
	inputSource  = flag.String("input", "", "Input source to switch to.")
	volume       = flag.String("volume", "", "Up, down, or a value in DB (e.g; 32.5)")
	mode         = flag.String("mode", "", "DIRECT, MCH STEREO, STEREO, etc.")
	debug        = flag.Bool("debug", false, "Print out debug messages.")
)

func main() {
	flag.Parse()
	args := flag.Args()

	for _, a := range args {
		cmd := strings.ToLower(a)
		switch cmd {
		case "up":
			volume = &cmd
		case "down":
			volume = &cmd
		case "direct":
			m := "DIRECT"
			mode = &m
		case "stereo":
			m := "MCH STEREO"
			mode = &m
		}
	}

	conn, err := net.Dial("tcp", *denonAddress+":23")
	if err != nil {
		fmt.Printf("Could not connect to %s: %v\n", *denonAddress, err)
		return
	}

	commands := []string{}
	if *volume != "" {
		switch strings.ToLower(*volume) {
		case "up":
			commands = append(commands, "MVUP")
		case "down":
			commands = append(commands, "MVDOWN")
		default:
			f, err := strconv.ParseFloat(*volume, 32)
			if err != nil {
				fmt.Printf("Could not parse %s: %v\n", *volume, err)
				return
			}

			// Denon uses an inverse scale in the API from what
			// is displayed on screen. The range is [0, 80]. The
			// TV displays 0+delta, the API is 80-delta. So we
			// fix it here to make it consistent for humans.
			i := int(800 - f*10)
			i = i - (i % 5) // Denon takes it in 0.5 increments only.

			commands = append(commands, "MV"+strconv.Itoa(i))
		}
	}

	if *inputSource != "" {
		source := strings.ToUpper(*inputSource)
		commands = append(commands, "SI"+source)
	}

	if *mode != "" {
		m := strings.ToUpper(*mode)
		commands = append(commands, "MS"+m)
	}

	for _, cmd := range commands {
		buf := make([]byte, len(cmd)+1)
		copy(buf, cmd)
		buf[len(cmd)] = '\r'
		conn.Write(buf)
	}

	conn.SetReadDeadline(time.Now().Add(100 * time.Millisecond))
	r := bufio.NewReader(conn)
	for {
		line, err := r.ReadString('\r')
		if err != nil {
			break
		}
		if *debug {
			fmt.Printf("Read: %s\n", line)
		}
	}

	conn.Close()
}
