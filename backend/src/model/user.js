export class User {
	constructor(id, email, password, isAdmin, createdAt) {
        this.id = id
        this.email = email
        this.password = password
        this.isAdmin = isAdmin
        this.createdAt = createdAt
    }
}
