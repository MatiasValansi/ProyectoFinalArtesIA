import { User } from "../model/user.js";
import { UserRepository } from "../repository/user.repository.js";

export const UserService = {
    serviceUserValidation: async (id) => {
        const idUser = await UserRepository.getById(id)
        if (!idUser) return null;

        return idUser;
    },

    serviceUserCreation: (userToCreate) => {
        const userData = {
            ...userToCreate,
            id: crypto.randomUUID().toString()
        }

        const modelUserToCreate = new User(userData.id, userData.email,userData.password,userData.isAdmin,userData.createdAt)

        UserRepository.createOne(modelUserToCreate)
        
        return modelUserToCreate
    },

    serviceUserDelete: (id) => {
        const idUserToDelete = UserRepository.deleteById(id) 
        
        if (!idUserToDelete) return null
        return idUserToDelete
    }
}
