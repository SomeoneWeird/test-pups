package main

import (
	"fmt"
	"net/http"
)

func handler(w http.ResponseWriter, r *http.Request) {
	fmt.Fprintf(w, "hello server3")
}

func main() {
	http.HandleFunc("/", handler)
	fmt.Println("Starting server on :8082")
	http.ListenAndServe(":8082", nil)
}
