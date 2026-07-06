# Replacing Committer Name and Email on Commits

## Scenario

Have you ever made a series of commits and forgot to change git's local config for your name and email?

Here we'll take a look at how to replace commits with the wrong name and email associated with them.

## Tools

### Install uv with brew

```sh
brew install uv
```

### Install git-filter-repo with uv

```sh
uv tool install git-filter-repo
```

## Operation

### Create a directory to work in and jump into it

This directory will hold a clone of the repository and a `mailmap` file for remapping the user's name and email address.

```sh
mkdir ~/fix-emails && cd $_
```

### Create a mailmap file in the work directory

If you try to do this in the repo itself, you get the following warning:

```Aborting: Refusing to destructively overwrite repo history since
this does not look like a fresh clone.
  (you have untracked changes)
Please operate on a fresh clone instead.  If you want to proceed
anyway, use --force.
```

The syntax is gitmailmerge.

```text
Proper Name <proper@email.xx> Commit Name <commit@email.xx>
```

Or another way to look at the syntax:

```text
Name-to-change-to <email@tochange.to> Name-currently-on-commits <email@tobechang.ed>
```

Now create the mailmerge file.

```sh
cat > mailmap <<EOF
blitterated <blitterated@protonmail.com> Real Name <realn@foo.bar>
EOF
```

### Pull down a fresh clone of your repo

```sh
git clone git@github.com:blitterated/some-repo.git
```

At this point, your directory structure should look something like this:

```text
.
├── some-repo
│   ├── .gitignore
│   ├── some-script.sh
│   └── README.md
└── mailmap
```


### OPTIONAL: Back up your repo for convenience

```sh
gtar -I 'gzip -9' -cvf some_repo_yyyymmdd.tgz some_repo_dir
```


### cd into your cloned repo's directory

```sh
cd some-repo
```


### Capture current history

Use it to double check after filtering the repo.

```sh
git log --date=short --pretty=format:"%h%x09%an%x09%ad%x09%s"
```

```text
91581f4 blitterated     2025-05-18      Added FROM comments to Dockerfile
cf15700 blitterated     2023-12-06      factored out  lines
d249140 Pete Young      2023-12-01      v2, v3 legacy, and v3 builds working
433b591 Pete Young      2023-12-01      Clean build and run cribsheet
3e945fc Pete Young      2023-12-01      Added compression description
53db061 Pete Young      2023-11-30      Added info on compression differnces
8414cf4 Pete Young      2023-11-15      v3 builds working. v2 mostly. Added README
2f32730 Pete Young      2023-11-15      Removed execute flag from run and finish scripts
5b73e3e Pete Young      2023-11-14      Refactored build scripts, added tests
edbc1a0 Pete Young      2023-11-14      Config validation for v3 build
366f4a6 Pete Young      2023-11-14      Using Heredocs in Dockerfile
64cc383 Pete Young      2023-11-14      Split out common build functions to an include
439b8b0 Pete Young      2023-11-14      Changed image name for v3 builds
0fb1e8b Pete Young      2023-11-14      Renamed v3 s6-rc.d build script
995ada2 Pete Young      2023-11-14      Added README.md
4feb81a Pete Young      2023-11-14      Removed services.d from s6-rc.d build script
6bd160e Pete Young      2023-11-14      Builds for s6-overlay v3 working
b77f2fd Pete Young      2023-11-13      moved Dockerfile to root
16b4ae9 Pete Young      2023-11-13      initial commit
```


### Run git-filter-repo

```sh
git filter-repo --force --mailmap ../mailmap | tee ../some_repo_author_fix.log
```

```text
Parsed 19 commitsHEAD is now at 167a3bc Some commit message here
Enumerating objects: 74, done.
Counting objects: 100% (74/74), done.
Delta compression using up to 16 threads
Compressing objects: 100% (71/71), done.
Writing objects: 100% (74/74), done.
Total 74 (delta 38), reused 0 (delta 0), pack-reused 0 (from 0)

New history written in 0.08 seconds; now repacking/cleaning...
Repacking your repo and cleaning out old unneeded objects
Completely finished after 0.21 seconds.
```


### Check the results

```sh
git log --date=short --pretty=format:"%h%x09%an%x09%ad%x09%s"
```

```text
git log --date=short --pretty=format:"%h%x09%an%x09%ad%x09%s"
177c3bd blitterated     2025-05-18      Added FROM comments to Dockerfile
7627a8a blitterated     2023-12-06      factored out  lines
b8abefe blitterated     2023-12-01      v2, v3 legacy, and v3 builds working
a0cd270 blitterated     2023-12-01      Clean build and run cribsheet
2d15aa0 blitterated     2023-12-01      Added compression description
9c5e429 blitterated     2023-11-30      Added info on compression differnces
3b6d35e blitterated     2023-11-15      v3 builds working. v2 mostly. Added README
67e98ce blitterated     2023-11-15      Removed execute flag from run and finish scripts
62d27c8 blitterated     2023-11-14      Refactored build scripts, added tests
9ed98da blitterated     2023-11-14      Config validation for v3 build
d30cd46 blitterated     2023-11-14      Using Heredocs in Dockerfile
9b8285e blitterated     2023-11-14      Split out common build functions to an include
16371fa blitterated     2023-11-14      Changed image name for v3 builds
e66e25f blitterated     2023-11-14      Renamed v3 s6-rc.d build script
9a1b225 blitterated     2023-11-14      Added README.md
a92f4ec blitterated     2023-11-14      Removed services.d from s6-rc.d build script
c210e24 blitterated     2023-11-14      Builds for s6-overlay v3 working
c6003df blitterated     2023-11-13      moved Dockerfile to root
6ddf639 blitterated     2023-11-13      initial commit
```

### Update the committer name and email for your repo

...so you don't run into the same problem again ;)

```sh
git config user.name "blitterated"
git config user.email "blitterated@protonmail.com"
```

## Push

### (Re-)add the remote repo

```sh
git remote add origin ghblit:blitterated/some-repo.git
```

### Push to remote

```sh
git push -u --force origin master
```

### Pull and rebase in other local clones

```sh
git pull --rebase
```

## References


- [GH: git-filter-repo](https://github.com/newren/git-filter-repo#simple-example-with-comparisons)
- [git-filter-repo man page:User and email based filtering
](https://htmlpreview.github.io/?https://github.com/newren/git-filter-repo/blob/docs/html/git-filter-repo.html#_user_and_email_based_filtering)
- [gitmailmap(5) Manual Page](https://htmlpreview.github.io/?https://raw.githubusercontent.com/newren/git-filter-repo/docs/html/gitmailmap.html#_syntax)
- [How can I change the author name / email of a commit?](https://www.git-tower.com/learn/git/faq/change-author-name-email)
