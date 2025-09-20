import { Router } from "express";
import { UserController } from "../controller/user.controller.js";

const userRouter = Router()

userRouter.get("/users", (req,res) => {})
userRouter.get("/users/:id", UserController.userValidation)
userRouter.post("/users", UserController.userCreateOne)
userRouter.put("/users/:id", (req,res) => {})
userRouter.delete("/users/:id", UserController.userDeleteOne)

export { userRouter }