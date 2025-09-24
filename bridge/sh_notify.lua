Notify = {}

function Notify.success(msg)
    lib.notify({ title = 'Vehicle Shop', description = msg, type = 'success' })
end

function Notify.error(msg)
    lib.notify({ title = 'Vehicle Shop', description = msg, type = 'error' })
end

function Notify.confirm(title, content)
    local alert = lib.alertDialog({
        header = title,
        content = content,
        centered = true,
        cancel = true,
        labels = { confirm = 'Yes', cancel = 'No' }
    })
    return alert == 'confirm'
end
