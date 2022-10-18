# How To Create A New Sudo Enabled User on Ubuntu 22.04 [Quickstart]

##  Step 1 — Logging Into Your Server
$ ssh root@your_server_ip_address\
\
##  Step 2 — Adding a New User to the System
$ adduser sammy\
Be sure to replace sammy with the username that you want to create. You will be prompted to create and verify a password for the user:\
\
Output\
Enter new UNIX password:
Retype new UNIX password:
passwd: password updated successfully
Next, you’ll be asked to fill in some information about the new user. It is fine to accept the defaults and leave this information blank:\
\
Output\
Changing the user information for sammy
Enter the new value, or press ENTER for the default\
    Full Name []:
    Room Number []:
    Work Phone []:
    Home Phone []:
    Other []:
Is the information correct? [Y/n]\
\
##  Step 3 — Adding the User to the sudo Group
$ usermod -aG sudo sammy\
\
##  Step 4 — Testing sudo Access
$  su - sammy\
\
As the new user, verify that you can use sudo by prepending sudo to the command that you want to run with superuser privileges:\
\
$ sudo command_to_run\

For example, you can list the contents of the /root directory, which is normally only accessible to the root user:\

$ sudo ls -la /root\

The first time you use sudo in a session, you will be prompted for the password of that user’s account. Enter the password to proceed:\

Output:\
[sudo] password for sammy:\
Note: This is not asking for the root password! Enter the password of the sudo-enabled user you just created.\

If your user is in the proper group and you entered the password correctly, the command that you issued with sudo will run with root privileges.\
