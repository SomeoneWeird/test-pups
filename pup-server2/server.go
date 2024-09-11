package main

import (
	"fmt"
	"net/http"
)

func handler(w http.ResponseWriter, r *http.Request) {
	fmt.Fprintf(w, "hello server2")
}

func main() {
	http.HandleFunc("/", handler)
	fmt.Println("Starting server on :8081")
	http.ListenAndServe(":8081", nil)
}
