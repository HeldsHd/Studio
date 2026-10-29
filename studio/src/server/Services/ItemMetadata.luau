--!strict
local HttpService = game:GetService("HttpService")
local Config = require(script.Parent.Parent.Config.MutationConfig)

export type Input = {
	schemaVersion: number?,
	mutationIds: { string }?,
	originEventId: string?,
}
export type Metadata = {
	schemaVersion: number,
	mutationIds: { string },
	originEventId: string?,
}
local ItemMetadata = {}

local function validId(value: string): boolean
	return value:match("^[%w_%-]+$") ~= nil
end

function ItemMetadata.Normalize(input: Input?): Metadata
	assert(input == nil or type(input) == "table", "Metadados inválidos")
	if input and input.schemaVersion ~= nil then
		assert(input.schemaVersion == 1, "Versão de metadados não suportada")
	end
	local ids: { string } = {}
	local seen: { [string]: boolean } = {}
	local raw = if input then input.mutationIds else nil
	if raw ~= nil then
		assert(type(raw) == "table", "mutationIds deve ser uma lista")
		local count = 0
		for index, id in pairs(raw) do
			assert(type(index) == "number" and index >= 1 and index % 1 == 0, "Índice de mutação inválido")
			assert(type(id) == "string" and validId(id) and Config.Mutations[id] ~= nil,
				"Mutação desconhecida ou inválida")
			assert(not seen[id], "Mutação duplicada: " .. id)
			seen[id] = true
			count += 1
			table.insert(ids, id)
		end
		for index = 1, count do
			assert(raw[index] ~= nil, "Lista de mutações contém lacunas")
		end
	end
	table.sort(ids)
	local origin = if input then input.originEventId else nil
	assert(origin == nil or (type(origin) == "string" and validId(origin)),
		"Identificador do evento de origem inválido")
	local metadata: Metadata = {
		schemaVersion = 1,
		mutationIds = table.freeze(ids),
		originEventId = origin,
	}
	return table.freeze(metadata)
end

-- Apenas projeção. Nunca reconstituir a autoridade destes atributos.
function ItemMetadata.ApplyAttributes(instance: Instance, input: Input?)
	local metadata = ItemMetadata.Normalize(input)
	instance:SetAttribute("ItemMetadataVersion", metadata.schemaVersion)
	instance:SetAttribute("MutationIds",
		if #metadata.mutationIds == 0 then "[]" else HttpService:JSONEncode(metadata.mutationIds))
	instance:SetAttribute("OriginEventId", metadata.originEventId)
end

return ItemMetadata
