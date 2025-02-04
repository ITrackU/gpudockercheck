# Use the official PyTorch image with CUDA support
FROM pytorch/pytorch:1.9.0-cuda10.2-cudnn7-runtime

# Set the working directory in the container
WORKDIR /app

# Copy the current directory contents into the container at /app
COPY . /app

# Install any needed packages (if necessary)
RUN pip install --no-cache-dir torch

# Make port 80 available to the world outside this container
EXPOSE 80

# Run app.py when the container launches
CMD ["python", "app.py"]
