#!/bin/bash

if [ "$#" -ne 1 ]; then
	echo "usage: $0 client|server"
	exit 1
fi

process=$1

if [ "$process" = "client" ]; then
	java -cp /home/sd/sd.jar sd.lab1.TcpClient
elif [ "$process" = "server" ]; then
	java -cp /home/sd/sd.jar sd.lab1.TcpServer
else
	echo "Invalid option $process"
	echo "usage $0 client|server"
	exit 1
fi