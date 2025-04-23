//
//  ProfileView.swift
//  Lookup8
//
//  Created by You on 2025-04-23.
//

import SwiftUI

struct ProfileView: View {
    // MARK: — 登录态 & 当前用户名
    @AppStorage("isLoggedIn")    private var isLoggedIn    = false
    @AppStorage("profileUsername") private var storedUsername = ""

    // MARK: — 界面状态
    @State private var showingRegister = false
    @State private var username        = ""
    @State private var password        = ""
    @State private var confirmPassword = ""
    @State private var errorMessage: String?

    var body: some View {
        NavigationStack {
            Group {
                if isLoggedIn {
                    loggedInView
                } else if showingRegister {
                    registerForm
                } else {
                    loginForm
                }
            }
            .navigationTitle("Profile")
        }
    }

    // MARK: — 登录 表单
    private var loginForm: some View {
        VStack(spacing: 20) {
            Spacer()

            Text("Welcome Back")
                .font(.largeTitle).bold()

            // 用户名
            TextField("Username", text: $username)
                .textFieldStyle(.roundedBorder)
                .autocapitalization(.none)
                .disableAutocorrection(true)

            // 密码
            SecureField("Password", text: $password)
                .textFieldStyle(.roundedBorder)

            // 错误提示
            if let msg = errorMessage {
                Text(msg)
                    .foregroundColor(.red)
                    .font(.caption)
            }

            // 登录按钮
            Button("Sign In") {
                signIn()
            }
            .buttonStyle(.borderedProminent)
            .disabled(username.isEmpty || password.isEmpty)

            // 切到注册表单
            Button("Register") {
                errorMessage     = nil
                password         = ""
                confirmPassword  = ""
                showingRegister  = true
            }
            .font(.footnote)

            Spacer()
        }
        .padding()
    }

    // MARK: — 注册 表单
    private var registerForm: some View {
        VStack(spacing: 20) {
            Spacer()

            Text("Create Account")
                .font(.largeTitle).bold()

            // 新用户名
            TextField("Choose a Username", text: $username)
                .textFieldStyle(.roundedBorder)
                .autocapitalization(.none)
                .disableAutocorrection(true)

            // 密码
            SecureField("Password", text: $password)
                .textFieldStyle(.roundedBorder)

            // 确认密码
            SecureField("Confirm Password", text: $confirmPassword)
                .textFieldStyle(.roundedBorder)

            // 错误提示
            if let msg = errorMessage {
                Text(msg)
                    .foregroundColor(.red)
                    .font(.caption)
            }

            HStack {
                // 取消注册
                Button("Cancel") {
                    errorMessage    = nil
                    showingRegister = false
                }
                .buttonStyle(.bordered)

                Spacer()

                // 提交注册
                Button("Sign Up") {
                    signUp()
                }
                .buttonStyle(.borderedProminent)
                .disabled(username.isEmpty || password.isEmpty)
            }

            Spacer()
        }
        .padding()
    }

    // MARK: — 登录／注册／登出 逻辑
    private func signIn() {
        // 从 UserDefaults 里读密码（key = "pw_<username>"）
        let key   = "pw_\(username.lowercased())"
        let saved = UserDefaults.standard.string(forKey: key)

        if let saved = saved, saved == password {
            // 登录成功
            storedUsername = username
            isLoggedIn     = true
            errorMessage   = nil
        } else {
            errorMessage = "Invalid credentials"
        }
    }

    private func signUp() {
        // 基本校验
        guard password == confirmPassword else {
            errorMessage = "Passwords do not match"
            return
        }
        guard password.count >= 4 else {
            errorMessage = "Password too short"
            return
        }

        // 存到 UserDefaults
        let key = "pw_\(username.lowercased())"
        UserDefaults.standard.set(password, forKey: key)

        // 直接登录
        storedUsername = username
        isLoggedIn     = true
        errorMessage   = nil
    }

    private func signOut() {
        isLoggedIn    = false
        username      = ""
        password      = ""
        confirmPassword = ""
        // （可选）不清 storedUsername，保持下次打开依旧展示上次用户名
    }

    // MARK: — 登录后视图
    private var loggedInView: some View {
        Form {
            Section {
                HStack {
                    Image(systemName: "person.crop.circle.fill")
                        .resizable()
                        .frame(width: 60, height: 60)
                        .foregroundColor(.blue)
                    Text(storedUsername)
                        .font(.title2).bold()
                }
                .padding(.vertical, 8)
            }

            Section("My Bookmarks") {
                // 这里先示例写死几条，后面可以替换真实书签
                Text("📑 Frankenstein – Chapter 3")
                Text("📑 Moby Dick – Chapter 1")
                NavigationLink("See All…", destination: Text("Bookmarks List"))
            }

            Section {
                Button("Sign Out", role: .destructive) {
                    signOut()
                }
            }
        }
    }
}

#Preview {
    ProfileView()
}

