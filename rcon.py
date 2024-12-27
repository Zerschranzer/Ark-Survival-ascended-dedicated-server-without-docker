#!/usr/bin/env python3
import argparse
import socket
import struct
import re

DEBUG = False  # Debug mode is disabled by default

# Function: Debug output
def debug_print(message):
    if DEBUG:
        print("[DEBUG]", message)

# Function: Parse host and port from a single argument
def parse_host_port(host_port):
    match = re.match(r"^(.+):(\d+)$", host_port)
    if not match:
        raise argparse.ArgumentTypeError("Host must be specified in the format 'host:port'.")
    return match.group(1), int(match.group(2))

# Function: Create an RCON packet
def create_packet(request_id, packet_type, payload):
    payload_bytes = payload.encode('utf-8') + b'\x00\x00'
    packet_length = 4 + 4 + len(payload_bytes)
    return struct.pack(f'<iii{len(payload_bytes)}s', packet_length, request_id, packet_type, payload_bytes)

# Function: Parse the server's response
def parse_response(response):
    if len(response) < 12:
        raise ValueError("Response packet is too short.")
    request_id, response_type = struct.unpack('<ii', response[:8])
    payload = response[12:-2].decode('utf-8', errors='ignore')

    # Check for Keep Alive
    if payload.lower() == "keep alive":
        return request_id, response_type, "KEEP_ALIVE"

    return request_id, response_type, payload

# Function: Receive all data from the server
def recv_all(conn, buffer_size=4096):
    response = b""
    while True:
        part = conn.recv(buffer_size)
        response += part
        if len(part) < buffer_size:
            break
    return response

# Function: Send a command and handle responses
def send_command_and_process_response(conn, command):
    command_packet = create_packet(2, 2, command)
    conn.sendall(command_packet)

    while True:
        response = recv_all(conn)
        _, _, payload = parse_response(response)
        if payload != "KEEP_ALIVE":  # Ignore "Keep Alive" responses
            print("Response:", payload.strip())
            break

# Function: Connect to the RCON server and send commands
def send_rcon_command(host, port, password, command=None):
    try:
        with socket.create_connection((host, port), timeout=10) as conn:
            print(f"Connected to {host}:{port}")

            # Perform login if a password is provided
            if password:
                login_packet = create_packet(1, 3, password)
                conn.sendall(login_packet)
                response = recv_all(conn)
                request_id, _, payload = parse_response(response)
                if request_id == -1:  # -1 indicates login failure
                    print("Login failed! Please check the password.")
                    return
                print("Login successful!")

            # Send a single command if provided
            if command:
                send_command_and_process_response(conn, command)
                return

            # Interactive console
            print("Interactive console started. Type 'exit' or 'quit' to close.")
            while True:
                user_command = input("RCON> ")
                if user_command.lower() in {"exit", "quit"}:
                    print("Exiting interactive console. Goodbye!")
                    break
                send_command_and_process_response(conn, user_command)

    except socket.timeout:
        print("Error: Connection or response timed out (10 seconds).")
    except Exception as e:
        print(f"Error: {e}")

# Main function to parse arguments and execute commands
def main():
    global DEBUG
    parser = argparse.ArgumentParser(description="RCON Client for sending commands to a game server.")
    parser.add_argument("host_port", type=parse_host_port, help="Host and port in the format 'host:port'.")
    parser.add_argument("-p", "--password", required=True, help="RCON password.")
    parser.add_argument("-c", "--command", help="A single RCON command to send.")
    parser.add_argument("--debug", action="store_true", help="Enable debug mode.")

    args = parser.parse_args()
    DEBUG = args.debug

    host, port = args.host_port
    send_rcon_command(host, port, args.password, args.command)

if __name__ == "__main__":
    main()
