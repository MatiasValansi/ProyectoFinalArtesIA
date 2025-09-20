import { JsonHandler } from "../utils/JsonManager.js";

export const CaseRepository = {
    getAll: async () => await JsonHandler.read(),

    getById: async (id) => {
        const cases = await JsonHandler.read()

        if(!cases) return null

        const caseFound = cases.find((caseById) => caseById == id)

        if (!caseFound) return null

        return caseFound
    }
}