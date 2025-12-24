# Use an official Python runtime as a parent image
# Using 'slim' version to keep the image size small
FROM python:3.9-slim

# Set the working directory in the container
WORKDIR /app

# Copy the requirements file into the container
COPY requirements.txt .

# Install any needed packages specified in requirements.txt
RUN pip install --no-cache-dir -r requirements.txt

# Copy the rest of the application code
COPY . .

# Create a directory for the database to ensure persistence
RUN mkdir -p /app/data

# Make port 5000 available to the world outside this container
EXPOSE 5000

# Define environment variable (optional, ensures output is logged immediately)
ENV PYTHONUNBUFFERED=1

# Run app.py when the container launches
CMD ["python", "app.py"]