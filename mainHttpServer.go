package main

import (
	"flag"
	"fmt"
	"io"
	"net"
	"net/http"
	"strings"
	"sync"
	"time"

	"github.com/gin-gonic/gin"
)

type VLCConnection struct {
	conn   net.Conn
	mutex  sync.Mutex
	closed bool
	addr   string
}

var vlcConn *VLCConnection

func initVLCConnection(addr string) error {
	conn, err := net.Dial("tcp", addr)
	if err != nil {
		return fmt.Errorf("failed to connect to VLC: %v", err)
	}

	vlcConn = &VLCConnection{conn: conn, addr: addr}

	// Read and ignore the initial VLC welcome message
	buffer := make([]byte, 1024)
	_, err = conn.Read(buffer)
	if err != nil {
		conn.Close()
		return fmt.Errorf("failed to read initial VLC message: %v", err)
	}

	return nil
}

func (vc *VLCConnection) sendCommand(command string) (string, error) {
	vc.mutex.Lock()
	defer vc.mutex.Unlock()

	if vc.closed {
		return "", fmt.Errorf("connection is closed")
	}

	// Clear any leftover data in the buffer
	vc.conn.SetReadDeadline(time.Now().Add(100 * time.Millisecond))
	buffer := make([]byte, 1024)
	for {
		_, err := vc.conn.Read(buffer)
		if err != nil {
			break
		}
	}
	vc.conn.SetReadDeadline(time.Time{}) // Reset the read deadline

	// Set a read/write timeout for the command
	vc.conn.SetDeadline(time.Now().Add(5 * time.Second))

	// Send the command to VLC
	_, err := fmt.Fprintf(vc.conn, "%s\n", command)
	if err != nil {
		return "", fmt.Errorf("failed to send command to VLC: %v", err)
	}

	// Read the response from VLC
	var response strings.Builder
	for {
		n, err := vc.conn.Read(buffer)
		if err != nil {
			if err == io.EOF {
				break
			}
			return "", fmt.Errorf("failed to read response from VLC: %v", err)
		}
		response.Write(buffer[:n])

		// Check for the prompt in response
		if strings.Contains(response.String(), "> ") {
			break
		}
	}

	// Process the response: remove everything up to and including the command
	responseStr := response.String()
	cmdIndex := strings.Index(responseStr, command)
	if cmdIndex != -1 {
		responseStr = responseStr[cmdIndex+len(command):]
	}

	// Remove the trailing prompt
	responseStr = strings.TrimSuffix(responseStr, "> ")

	return strings.TrimSpace(responseStr), nil
}

func (vc *VLCConnection) close() {
	vc.mutex.Lock()
	defer vc.mutex.Unlock()

	if !vc.closed {
		vc.conn.Close()
		vc.closed = true
	}
}

func (vc *VLCConnection) reconnect() error {
	vc.mutex.Lock()
	defer vc.mutex.Unlock()

	if !vc.closed {
		vc.conn.Close()
	}

	conn, err := net.Dial("tcp", vc.addr)
	if err != nil {
		return fmt.Errorf("failed to reconnect to VLC: %v", err)
	}

	vc.conn = conn
	vc.closed = false

	// Read and ignore the initial VLC welcome message
	buffer := make([]byte, 1024)
	_, err = conn.Read(buffer)
	if err != nil {
		conn.Close()
		return fmt.Errorf("failed to read initial VLC message: %v", err)
	}

	return nil
}

func main() {
	// Define command-line flags
	vlcServer := flag.String("server", "localhost", "VLC server address")
	vlcPort := flag.Int("port", 9000, "VLC server port")
	httpPort := flag.Int("http", 9091, "HTTP server port")

	// Parse the flags
	flag.Parse()

	// Construct the VLC address
	vlcAddr := fmt.Sprintf("%s:%d", *vlcServer, *vlcPort)

	err := initVLCConnection(vlcAddr)
	if err != nil {
		fmt.Printf("Failed to initialize VLC connection: %v\n", err)
		return
	}
	defer vlcConn.close()

	router := gin.Default()

	// Route to handle VLC commands
	router.POST("/vlc/:command", func(c *gin.Context) {
		command := c.Param("command")

		// Forward the command to VLC
		response, err := vlcConn.sendCommand(command)
		if err != nil {
			c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
			return
		}

		// Send response back to client
		proper := strings.Split(response, "\r\n")
		c.JSON(http.StatusOK, gin.H{"response": proper})
	})

	// Start the Gin server
	fmt.Printf("Starting HTTP server on port %d\n", *httpPort)
	router.Run(fmt.Sprintf(":%d", *httpPort))
}
