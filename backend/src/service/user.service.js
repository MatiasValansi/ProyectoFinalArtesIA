import { User } from "../model/user.js";
import { UserRepository } from "../repository/user.repository.js";
import { SupabaseUserRepository } from "../repository/user.supabase.repository.js";

export const UserService = {

    serviceUserAll: async () => {
        const users = await SupabaseUserRepository.getAll()
        if (!users) return null

        return users
    },

    serviceUserValidation: async (id) => {
        const idUser = await UserRepository.getById(id)
        if (!idUser) return null;

        return idUser;
    },

    serviceUserCreation: async (userToCreate) => {
        const userData = {
            ...userToCreate,
            id: crypto.randomUUID().toString()
        }

        const modelUserToCreate = new User(userData.id, userData.email,userData.password,userData.isAdmin,userData.createdAt)

        await UserRepository.createOne(modelUserToCreate)
        
        return modelUserToCreate
    },

    serviceUserDelete: (id) => {
        const idUserToDelete = UserRepository.deleteById(id) 
        
        if (!idUserToDelete) return null
        return idUserToDelete
    }
}
