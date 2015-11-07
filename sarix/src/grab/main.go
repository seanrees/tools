// Command grab captures a single frame from a Sarix camera.
//
package main

import (
	"flag"
	"io"
	golog "log"
	"net/http"
	"os"
	"time"
)

var (
	url       = flag.String("url", "", "Host or IP of Sarix camera.")
	frequency = flag.Duration("frequency", 1*time.Second, "How often to capture each frame.")
	output    = flag.String("output", "grab.jpg", "Output file")
)

func main() {
	flag.Parse()
	log := golog.New(os.Stderr, "", golog.Ldate|golog.Ltime|golog.Lshortfile)

	log.Printf("Capturing from %s every %v", *url, *frequency)
	c := time.Tick(*frequency)
	for {
		<-c // Block on tick.

		resp, err := http.Get(*url)
		if err != nil {
			log.Printf("Could not capture frame: %v", err)
			continue
		}

		if resp.StatusCode != 200 {
			log.Printf("Got unexpected status from camera: %s", resp.Status)
			continue
		}

		f, err := os.Create(*output)
		if err != nil {
			log.Printf("Could not open %s for writing: %v", err)
			continue
		}

		written, err := io.Copy(f, resp.Body)
		if written < resp.ContentLength {
			log.Printf("Truncated write to %s, wrote %d of %d", *output, written, resp.ContentLength)
		}
		f.Close()
	}
}
