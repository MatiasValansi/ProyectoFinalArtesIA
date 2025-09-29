import { Router } from "express";
const statusRouter = Router()

statusRouter.get(
    "/status", (req, res) => {
    res.json(
    {
        status: 200,
        timeStatus: new Date().toISOString(),
        message: "Proyecto Nestlé - Validación de Artes con IA"
    }
    )
})


export {statusRouter}