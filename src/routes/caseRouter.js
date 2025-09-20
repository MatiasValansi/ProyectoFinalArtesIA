import { Router } from "express";
import { CaseController } from "../controller/case.controller.js";


const caseRouter = Router()

caseRouter.get("/cases", (req,res) => {})
caseRouter.get("/cases/:id", CaseController.caseValidation)
caseRouter.post("/cases", (req,res) => {})
caseRouter.put("/cases/:id", (req,res) => {})
caseRouter.delete("/cases/:id", (req,res) => {})

export {caseRouter}