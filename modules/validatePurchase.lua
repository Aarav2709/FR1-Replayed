-- validatePurchase.lua — IAP validation (disabled stub)
local validatePurchase = {}
function validatePurchase.validate(receipt, callback)
    print("[validatePurchase] validate (disabled stub)")
    if callback then callback(false) end
end
return validatePurchase
