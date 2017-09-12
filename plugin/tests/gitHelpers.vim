" WHAT: Helpers for git

function s:getGitOutput(cmd)
    redir => outputStr
        silent exe a:cmd
    redir END
    let outputStr = substitute(outputStr, "\r", "", "g")
    let outputList = split(outputStr, "\n")
    return outputList[1:]
endfunction

function s:assertEnvHasFugitive()
    if exists(':Git') == 0
        throw "ERROR: Fugitive not available for current file"
    endif
endfunction

function s:assertNoLocalChanges()
    let gitLocalChanges = s:getGitOutput('Git status --porcelain')
    if len(gitLocalChanges) > 1
        throw "ERROR: Git has local changes"
    endif
endfunction

function s:getCurrentBranch()
    let gitCurrentBranch = s:getGitOutput('Git symbolic-ref --short HEAD')
    if len(gitCurrentBranch) > 1 
        throw "ERROR: Unexpectedly, gitCurrentBranch has len > 1"
    endif
    return gitCurrentBranch[0]
endfunction

function s:checkoutBranch(branch)
    let output = s:getGitOutput('Git checkout ' . a:branch)
    if output[0] != "Switched to branch '" . a:branch . "'"
        throw "ERROR: Couldn't switch branches to " . a:branch
    endif
endfunction

function s:pull()
    let output = s:getGitOutput('Git pull')
    let output = s:getGitOutput('Git pull')
    if output[0] != "Already up-to-date."
        throw "ERROR: Git pull is not working"
    endif
endfunction

function s:rebase()
    call s:assertEnvHasFugitive()
    call s:assertNoLocalChanges()
    let gitCurrentBranch = s:getCurrentBranch()

    if gitCurrentBranch == 'master'
        throw "ERROR: Shouldn't rebase master"
    endif

    call s:checkoutBranch('master')
    call s:pull()

    call s:checkoutBranch(gitCurrentBranch)
    call s:pull()

    "Git rebase master
    "Git rebase master -i
    "Git push -f
endfunction


command! Grebase call s:rebase()
