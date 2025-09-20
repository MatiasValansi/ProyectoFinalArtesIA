import { CaseRepository } from "../repository/case.repository.js"

export const CaseService = {
    serviceCaseValidation: async (id) => {
        const idCase = await CaseRepository.getById(id)
        if(!idCase) return null

        return idCase
    }
}