import { CaseService } from "../service/case.service.js"

export const CaseController = {
    caseValidation : async (req,res) => {
        const {id} = req.params
        const caseById = await CaseService.serviceCaseValidation(id)

        if (!caseById) {
            res.status(404).json({
                payload: null,
                message: "El caso no fue hallado",
                ok: false
            })
            return null
        } else {
            res.status(200).json({
                message: "Success 🟢🟢🟢",
                payload: caseById.id,
                caso: caseById,
                ok: true
            })
        }
    }
}