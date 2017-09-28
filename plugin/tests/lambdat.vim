
function! LambdatInvoke()
    let path = expand('%:h')
    let terminalCommand = 'lambdat invoke ' . path
    call ExecuteInShell(terminalCommand, 'right')
endfunction

function! LambdatDeploy()
    let path = expand('%:h')
    let terminalCommand = 'lambdat deploy ' . path
    call ExecuteInShell(terminalCommand, 'right')
endfunction

command! LambdatInvoke call LambdatInvoke()
command! LambdatDeploy call LambdatDeploy()

