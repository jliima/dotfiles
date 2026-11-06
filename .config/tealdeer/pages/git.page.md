# git

> Pages of subcommands stay available: tldr git-rebase.

- List local and remote branches:

`git branch --all`

- Add a new branch and switch to it:

`git switch --create branch_name`

- Rename a branch:

`git branch --move old_name new_name`

- Undo the previous commit but keep its changes staged:

`git reset --soft HEAD~1`

- Change the previous commit message:

`git commit --amend --only --message {{"new_message"}}`

- Change the previous commit time (author and committer):

`GIT_COMMITTER_DATE={{"2026-11-06T12:00:00"}} git commit --amend --only --no-edit --date {{"2026-11-06T12:00:00"}}`
