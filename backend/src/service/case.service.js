import { CaseRepository } from "../repository/case.repository.js"

export const CaseService = {
    
    serviceCaseAll: async () => {
        const cases = await CaseRepository.getAll()
        if(!cases) return null

        return cases
    },

    serviceCaseValidation: async (id) => {
        const idCase = await CaseRepository.getById(id)
        if(!idCase) return null

        return idCase
    },



}