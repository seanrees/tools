package main

import (
	"flag"
	"log"
	"net/http"
	"net/url"
)

func main() {
	server := flag.String("server", "", "Server to test")
	fetchurl := flag.String("url", "", "URL to test")
	silent := flag.Bool("silent", true, "Silent mode")
	flag.Parse()

	proxy, err := url.Parse(*server)
	if err != nil {
		log.Fatal(err)
	}
	client := &http.Client{
		Transport: &http.Transport{
			Proxy: http.ProxyURL(proxy)}}
	resp, err := client.Get(*fetchurl)
	if err != nil {
		log.Fatal(err)
	}
	defer resp.Body.Close()
	if !*silent {
		log.Printf("received status=%s, length=%d\n",
			resp.Status, resp.ContentLength)
	}
}
