# for idea
# you can see
# https://youtrack.jetbrains.com/issue/IDEA-228656
netsh int ipv4 add excludedportrange tcp 6940 60 persistent

# for self
# keep some self using port
netsh int ipv4 add excludedportrange tcp 30000 1000 persistent
