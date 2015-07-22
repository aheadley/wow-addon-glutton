local myname, Glutton = ...

Glutton.PATTERN_FOODLIKE    = 'Must remain seated while'
Glutton.PATTERN_FOOD        = 'Use: Restores (%d+) health over (%d+) sec.'
Glutton.PATTERN_DRINK       = 'Use: Restores (%d+) mana over (%d+) sec.'
Glutton.PATTERN_BOTH        = 'Use: Restores (%d+) health and (%d+) mana over (%d+) sec.'
Glutton.MACRO_NAME_HP       = 'AutoHP'
Glutton.MACRO_NAME_MP       = 'AutoMP'
Glutton.MACRO_CONTENT       = '#showtooltip\n/use %s'

function Glutton:findConsumableItem(itemTextProcessor)
    local targetItem = {
        bagID = 0;
        slotID = 0;
        itemID = 0;
        restoreValue = 0;
    };

    self:inventoryApply(
        self:getConsumableItemSelector(itemTextProcessor, targetItem)
    );

    return targetItem
end

function Glutton:inventoryApply(map_func)
    for bagID = 0, NUM_BAG_SLOTS do
        local slotCount = GetContainerNumSlots(bagID);
        for slotID = 1, slotCount do
            local itemID = GetContainerItemID(bagID, slotID);
            if itemID ~= nil then
                map_func(bagID, slotID, itemID);
            end
        end
    end
end

function Glutton:getConsumableItemSelector(processor, selectedItem)
    local playerLevel = UnitLevel('player');
    return function(bagID, slotID, itemID)
        local itemInfo = {GetItemInfo(itemID)};
        local itemText = self:getItemTooltipText(bagID, slotID, itemID);
        if IsUsableItem(itemID) and self:isNoncombatConsumable(itemText) and
                playerLevel >= itemInfo[5] then
            value = processor(self, itemText);
            if value > selectedItem.restoreValue then
                selectedItem.bagID = bagID;
                selectedItem.slotID = slotID;
                selectedItem.itemID = itemID;
                selectedItem.restoreValue = value;
            end
        end
    end
end

function Glutton:isNoncombatConsumable(text)
    return text.find(text, self.PATTERN_FOODLIKE) ~= nil;
end

function Glutton:processDrinkItemText(text)
    local value = text.match(text, self.PATTERN_BOTH);
    if value == nil then
        value = text.match(text, self.PATTERN_DRINK);
    end
    if value == nil then
        value = -1;
    end
    return tonumber(value)
end

function Glutton:processFoodItemText(text)
    local value = text.match(text, self.PATTERN_BOTH);
    if value == nil then
        value = text.match(text, self.PATTERN_FOOD);
    end
    if value == nil then
        value = -1;
    end
    return tonumber(value)
end

function Glutton:getItemTooltipText(bagID, slotID)
    self.scanTooltip:ClearLines();
    self.scanTooltip:SetBagItem(bagID, slotID);

    local ttText = "";
    for i=1, self.scanTooltip:NumLines() do
        ttText = ttText .. _G['GluttonScanningTooltipTextLeft'.. i]:GetText();
    end

    return ttText
end

function Glutton:updateMacro(macroName)
    local idx = GetMacroIndexByName(macroName);
    if idx ~= 0 then
        local item = self:findConsumableItem(
            self.MACRO_PROCESSOR_TABLE[macroName]);
        if item.itemID ~= 0 then
            local itemName = GetItemInfo(item.itemID);

            EditMacro(idx, self.macroName, 1,
                self.MACRO_CONTENT:format(itemName));
        end
    end
end

function Glutton:updateMacros()
    for k, v in pairs(self.MACRO_PROCESSOR_TABLE) do
        self:updateMacro(k);
    end
end

Glutton.MACRO_PROCESSOR_TABLE   = {
    [Glutton.MACRO_NAME_HP] = Glutton.processFoodItemText;
    [Glutton.MACRO_NAME_MP] = Glutton.processDrinkItemText;
};


Glutton.eventFrame = CreateFrame('FRAME', 'Glutton_EventsFrame');
Glutton.eventFrameMap = {};

function Glutton.eventFrameMap:PLAYER_ENTERING_WORLD(...)
    Glutton.scanTooltip = CreateFrame('GAMETOOLTIP', 'GluttonScanningTooltip',
        nil, 'GameTooltipTemplate');
    Glutton.scanTooltip:SetOwner(WorldFrame, 'ANCHOR_NONE');

    Glutton:updateMacros();
end

function Glutton.eventFrameMap:BAG_UPDATE(...)
    if not UnitAffectingCombat('player') then
        Glutton:updateMacros();
    end
end

function Glutton.eventFrameMap:PLAYER_REGEN_ENABLED(...)
    Glutton:updateMacros();
end

Glutton.eventFrame:SetScript('OnEvent',
    function(self, event, ...)
        Glutton.eventFrameMap[event](self, ...);
    end);

for k, v in pairs(Glutton.eventFrameMap) do
    Glutton.eventFrame:RegisterEvent(k);
end
