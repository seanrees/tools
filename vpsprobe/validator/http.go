package validator

import (
	"fmt"
	"net/http"
	"net/url"
)

type HTTPError struct {
	What string
}

func (e *HTTPError) Error() string {
	return e.What
}

func ValidateHTTP(server string, fetchUrl string, code int) (bool, error) {
	proxy, err := url.Parse(server)
	if err != nil {
		return false, err
	}
	client := &http.Client{
		Transport: &http.Transport{
			Proxy: http.ProxyURL(proxy)},
		CheckRedirect: func(req *http.Request, via []*http.Request) error {
			return &HTTPError{"redirect following prohibited"}
		}}
	resp, err := client.Get(fetchUrl)
	if resp == nil {
		return false, err
	}
	defer resp.Body.Close()

	if resp.StatusCode != code {
		return false, &HTTPError{
			fmt.Sprintf("got http code %d, expected %d",
				resp.StatusCode, code)}
	}
	return true, nil
}
