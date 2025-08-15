local message_queue = {
    queue = {}
}

-----------------------------------------------------------
-- Empties all items from the queue
function message_queue:reset()
    self.queue = {}
end

-----------------------------------------------------------
-- Gets the current queue size
function message_queue:count()
    return #self.queue
end

-----------------------------------------------------------
-- Gets the current queue size (same as count)
function message_queue:size()
    return #self.queue
end

-- -----------------------------------------------------------
-- --
-- function message_queue:enqueue_raw(player_name, linkshell_name, message)
--     return self:enqueue_message({
--         timestamp = os.date("!%Y-%m-%dT%H:%M:%SZ"),
--         player_name = player_name,
--         linkshell_name = linkshell_name,
--         message = message
--     })
-- end

-----------------------------------------------------------
-- Appends an item at the end of the queue
function message_queue:enqueue(item)
    if item then
        table.insert(self.queue, item)
    end

    return item
end

-----------------------------------------------------------
-- Returns the next item in the queue without removing it
function message_queue:peek()
    return #self.queue[1]
end

-----------------------------------------------------------
-- Returns the next item in the queue after removing it
function message_queue:dequeue()
    local result = self.queue[1]
    if #self.queue > 0 then
        table.remove(self.queue, 1)
    end
    return result
end

return message_queue