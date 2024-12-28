#!/usr/bin/env python3
import argparse
import socket
import struct
import re

DEBUG = False  # Enable debug output if set to True
SILENT = False  # Suppress connection details if set to True

def debug_print(message):
    if DEBUG:
        print("[DEBUG]", message)

def parse_host_port(host_port):
    # Parse host and port from 'host:port'
    debug_print(f"Parsing host and port from input: {host_port}")
    match = re.match(r"^(.+):(\d+)$", host_port)
    if not match:
        raise argparse.ArgumentTypeError("Host must be specified in the format 'host:port'.")
    host, port = match.group(1), int(match.group(2))
    debug_print(f"Parsed host: {host}, port: {port}")
    return host, port

def create_packet(request_id, packet_type, payload):
    # Build an RCON packet with a length, request ID, type, and payload
    payload_bytes = payload.encode('utf-8') + b'\x00\x00'
    packet_length = 4 + 4 + len(payload_bytes)
    packet = struct.pack(f'<iii{len(payload_bytes)}s',
                         packet_length, request_id, packet_type, payload_bytes)
    debug_print(f"Created packet: request_id={request_id}, type={packet_type}, payload='{payload}', length={packet_length}")
    return packet

def parse_response(response):
    # Extract request ID, response type, and payload from a packet
    debug_print(f"Parsing response packet of length {len(response)}")
    if len(response) < 12:
        raise ValueError("Response packet is too short.")
    request_id, response_type = struct.unpack('<ii', response[4:12])
    payload = response[12:-2].decode('utf-8', errors='ignore')
    debug_print(f"Parsed response: request_id={request_id}, response_type={response_type}, payload='{payload}'")
    if payload.lower() == "keep alive":
        return request_id, response_type, "KEEP_ALIVE"
    return request_id, response_type, payload

def receive_packets(conn, buffer_size=4096):
    # Read and parse all available packets
    debug_print("Receiving packets from server...")
    packets = []
    data = b""
    while True:
        try:
            part = conn.recv(buffer_size)
            if not part:
                break
            data += part
            debug_print(f"Received raw data chunk of size {len(part)}")
            if len(part) < buffer_size:
                break
        except socket.timeout:
            debug_print("Socket timed out while receiving data.")
            break

    # Parse packets from the buffer
    offset = 0
    while True:
        if len(data) - offset < 4:
            break
        packet_length = struct.unpack('<i', data[offset:offset+4])[0]
        total_packet_size = 4 + packet_length
        if len(data) - offset < total_packet_size:
            break
        packet_data = data[offset:offset+total_packet_size]
        offset += total_packet_size
        debug_print(f"Parsing packet of size {total_packet_size}")
        packets.append(parse_response(packet_data))
    return packets

def send_command_and_process_response(conn, command):
    # Send a command and process all responses, ignoring 'KEEP_ALIVE'
    debug_print(f"Sending command: {command}")
    command_packet = create_packet(2, 2, command)
    conn.sendall(command_packet)
    while True:
        packets = receive_packets(conn)
        if not packets:
            debug_print("No more packets received.")
            break
        for _, _, payload in packets:
            if payload != "KEEP_ALIVE":
                debug_print(f"Processing response payload: {payload.strip()}")
                if SILENT:
                    print(payload.strip())
                else:
                    print("Response:", payload.strip())
                return

def send_rcon_command(host, port, password, command=None):
    # Connect to the server, authenticate, and handle commands
    debug_print(f"Attempting to connect to {host}:{port}")
    try:
        with socket.create_connection((host, port), timeout=10) as conn:
            debug_print("Connection established.")
            if not SILENT:
                print(f"Connecting to {host}:{port}...")
            if password:
                debug_print("Sending authentication packet.")
                login_packet = create_packet(1, 3, password)
                conn.sendall(login_packet)
                login_packets = receive_packets(conn)
                if any(req_id == -1 for req_id, _, payload in login_packets if payload != "KEEP_ALIVE"):
                    debug_print("Authentication failed.")
                    if not SILENT:
                        print("Login failed! Please check the password.")
                    return
                debug_print("Authentication successful.")
                if not SILENT:
                    print("Login successful!")
            if command:
                send_command_and_process_response(conn, command)
                return
            if not SILENT:
                print("Interactive console started. Type 'exit' or 'quit' to close.")
            while True:
                user_command = input("RCON> ")
                if user_command.lower() in {"exit", "quit"}:
                    debug_print("User exited interactive console.")
                    if not SILENT:
                        print("Exiting interactive console. Goodbye!")
                    break
                send_command_and_process_response(conn, user_command)
    except socket.timeout:
        debug_print("Connection or response timed out.")
        if not SILENT:
            print("Error: Connection or response timed out.")
    except Exception as e:
        debug_print(f"An exception occurred: {e}")
        if not SILENT:
            print(f"Error: {e}")

def main():
    global DEBUG, SILENT
    parser = argparse.ArgumentParser(description="RCON Client for sending commands to a game server.")
    parser.add_argument("host_port", type=parse_host_port, help="Host and port in the format 'host:port'.")
    parser.add_argument("-p", "--password", required=True, help="RCON password.")
    parser.add_argument("-c", "--command", help="A single RCON command to send.")
    parser.add_argument("--debug", action="store_true", help="Enable debug mode.")
    parser.add_argument("--silent", action="store_true", help="Suppress connection details, output only the response.")
    args = parser.parse_args()

    DEBUG = args.debug
    SILENT = args.silent

    debug_print(f"Parsed arguments: {args}")
    host, port = args.host_port
    send_rcon_command(host, port, args.password, args.command)

if __name__ == "__main__":
    main()
