# nuitv
a website for exploring new tv-shows and movies based on bottle and tailwindcss

## Running
First install dependencies with your prefered python package installer, we recommend pip:
``` bsh
pip3 install -r requirements.txt
```
Also install required npm packages
```bsh
npm i vite@8.0.14 tailwindcss@4.3 
```
Move into the source directory
```bsh
cd source
```
Now you need to write the database credentials into the .env file.
``` .env
NUITV_DB_HOST=web3.kinet.ch
NUITV_DB_USER=xxx
NUITV_DB_PASSWORD=xxx
NUITV_DB_NAME=omdb
```
Running the app for development is done with honcho:
```bsh
honcho start
```
An alternative to honcho would be to use npx concurrently
```bsh
npm i -D concurrently
npx concurrently "python3 server.py" "npx bite build --watch"
```
