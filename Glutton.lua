-- local myname, Glutton = ...


function SlashCmdList.GLUTTON_AUTOEAT(msg, editbox)
    SendChatMessage('auto eat command');
end
SLASH_GLUTTON_AUTOEAT1 = '/autoeat';

function SlashCmdList.GLUTTON_AUTODRINK(msg, editbox)
    SendChatMessage('auto drink command');
end
SLASH_GLUTTON_AUTODRINK1 = '/autodrink';


local EventsFrame = CreateFrame('FRAME', 'Glutton_EventsFrame');
local EventsFrameMap = {};

function EventsFrameMap:PLAYER_ENTERING_WORLD(...)
    SendChatMessage('player entering world');
end

function EventsFrameMap:BAG_UPDATE(...)
    SendChatMessage('bag update');
end


EventsFrame:SetScript('OnEvent',
    function(self, event, ...)
        EventsFrameMap[event](self, ...);
    end)

for k, v in pairs(EventsFrameMap) do
    EventsFrame:RegisterEvent(k);
end
