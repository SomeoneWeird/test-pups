package main

import (
	"bufio"
	"fmt"
	"math/rand"
	"net"
	"os"
	"time"
)

func main() {
	// Connect to the server
	conn, err := net.Dial("tcp", "count-server:9999")
	if err != nil {
		fmt.Println("Error connecting:", err)
		os.Exit(1)
	}
	fmt.Println("Successfully connected to the server")
	defer conn.Close()

	// List of 5 random words
	words := []string{"cat", "elephant", "bird", "rabbit", "hippopotamus"}
	rand.Seed(time.Now().UnixNano())
	rand.Shuffle(len(words), func(i, j int) { words[i], words[j] = words[j], words[i] })

	// Channel to signal when to send the next word
	ticker := time.NewTicker(1 * time.Second)
	defer ticker.Stop()

	go func() {
		for {
			// Read from the connection
			message, err := bufio.NewReader(conn).ReadString('\n')
			if err != nil {
				fmt.Println("Error reading:", err)
				return
			}
			fmt.Print("Received: ", message)
		}
	}()

	wordIndex := 0
	for range ticker.C {
		fmt.Println("Sending: ", words[wordIndex])

		// Send the next word
		_, err := fmt.Fprintf(conn, words[wordIndex]+"\n")
		if err != nil {
			fmt.Println("Error writing:", err)
			return
		}
		wordIndex = (wordIndex + 1) % len(words)
	}
}
