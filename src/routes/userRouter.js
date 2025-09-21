import { Router } from "express";
import { UserController } from "../controller/user.controller.js";
import { User } from "../model/user.js";

const userRouter = Router()

userRouter.get("/users", UserController.userAll)
userRouter.get("/users/:id", UserController.userValidation)
userRouter.post("/users", UserController.userCreateOne)
userRouter.put("/users/:id", UserController.userUpdateOne)
userRouter.delete("/users/:id", UserController.userDeleteOne)

export { userRouter }