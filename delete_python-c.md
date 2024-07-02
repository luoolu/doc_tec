$ ps -ef | grep "python -c" | grep -v "grep" | awk '{print $2}' | xargs kill -9
