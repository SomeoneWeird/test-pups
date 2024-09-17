package main

import (
	"bufio"
	"fmt"
	"net"
	"sync"
)

var (
	counter int
	mu      sync.Mutex
)

func handleConnection(conn net.Conn) {
	defer conn.Close()
	reader := bufio.NewReader(conn)
	for {
		message, err := reader.ReadString('\n')
		if err != nil {
			fmt.Println("Error reading from connection:", err)
			return
		}
		fmt.Printf("Received message: %s", message)
		mu.Lock()
		counter += len(message) - 1 // Subtract 1 to exclude the newline character
		total := counter
		mu.Unlock()
		response := fmt.Sprintf("Total characters received: %d\n", total)
		fmt.Printf("Sending response: %s", response)
		_, err = conn.Write([]byte(response))
		if err != nil {
			fmt.Println("Error writing to connection:", err)
			return
		}
	}
}

func main() {
	ln, err := net.Listen("tcp", ":9999")
	if err != nil {
		fmt.Println("Error starting server:", err)
		return
	}
	defer ln.Close()
	fmt.Println("Starting server on :9999")

	for {
		conn, err := ln.Accept()
		if err != nil {
			fmt.Println("Error accepting connection:", err)
			continue
		}
		fmt.Printf("New connection accepted from: %s\n", conn.RemoteAddr())
		go handleConnection(conn)
	}
}
