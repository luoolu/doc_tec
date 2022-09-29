How to Clone a Specific Branch
Now let's clone a specific branch from our demo repository. There are two ways to clone a specific branch. You can either:

Clone the repository, fetch all branches, and checkout to a specific branch immediately.
Clone the repository and fetch only a single branch.
## Option One
$ git clone --branch <branchname> <remote-repo-url>
or
$ git clone -b <branchname> <remote-repo-url>
  
## Option Two
$ git clone --branch <branchname> --single-branch <remote-repo-url>
or
$ git clone -b <branchname> --single-branch <remote-repo-url>
  
  
