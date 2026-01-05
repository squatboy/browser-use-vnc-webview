#!/bin/bash

# Docker image pre-build script
# Run this script before creating sessions to pre-build images.

set -e

echo "🔨 Starting Browser-Use VNC image pre-build..."

# Build VNC image
echo ""
echo "📦 Building VNC image..."
cd vnc
docker build -t browser-use-vnc:latest .
cd ..

# Build Agent image
echo ""
echo "📦 Building Agent image..."
cd agent
docker build -t browser-use-agent:latest .
cd ..

echo ""
echo "✅ All images built successfully!"
echo ""
echo "Built images:"
docker images | grep "browser-use-"

echo ""
echo "Sessions will now start quickly using pre-built images."
