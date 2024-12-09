# Use the official Python image
FROM python:3.9-slim

# Set the working directory in the container
WORKDIR /app

# Copy the current directory contents into the container
COPY . /app

# Install Python dependencies
RUN pip install --upgrade pip
RUN pip install --no-cache-dir -r requirements.txt

# Install debugpy for debugging
RUN pip install debugpy

# Expose ports for both the Flask app (5000) and debugging (5678)
EXPOSE 5000
EXPOSE 5678

# Run the application with debugpy and Gunicorn
CMD ["python", "-m", "debugpy", "--listen", "0.0.0.0:5678", "-m", "gunicorn", "-w", "4", "-b", "0.0.0.0:5000", "app:app"]


