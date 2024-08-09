#!/bin/bash

socat UNIX-CONNECT:serial_socket PTY,link=serial_pty &
screen serial_pty
