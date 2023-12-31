//
//  ContentView.swift
//  Wibu Chat
//
//  Created by DunkeyyFong on 10/09/2023.
//

import SwiftUI
import Firebase

struct LoginView: View {
    
    let didCompleteLoginProcess: () -> ()
    
    @State private var isLoginMode = false
    @State private var email = ""
    @State private var password = ""
    
    @State private var shouldShowImagePicker = false
    
    var body: some View {
        NavigationView {
            ScrollView {
                
                VStack(spacing: 16) {
                    
                    Picker(selection: $isLoginMode, label: Text("Picker here")) {
                        Text("Đăng nhập")
                            .tag(true)
                        Text("Tạo tài khoản")
                            .tag(false)
                    }.pickerStyle(SegmentedPickerStyle())
                    
                    if !isLoginMode {
                     
                        Button {
                            shouldShowImagePicker.toggle()
                        } label: {
                            // Tao tai khoan va dang nhap
                            VStack {
                                
                                if let image = self.image {
                                    Image(uiImage: image)
                                        .resizable()
                                        .frame(width: 128, height: 128)
                                        .scaledToFill()
                                        .cornerRadius(64)
                                } else {
                                    Image(systemName: "person.fill")
                                        .font(.system(size: 64))
                                        .foregroundColor(.orange)
                                        .padding()
                                }
                                
                            }
                            .overlay(RoundedRectangle(cornerRadius: 64)
                                        .stroke(Color.orange, lineWidth: 3)
                            )
                            
                            
                        }
                        
                    }
                    
                    Group {
                        TextField("Email", text: $email)
                            .keyboardType(.emailAddress)
                            .autocapitalization(.none)
                        SecureField("Mật khẩu", text: $password)
                    }
                    .padding(12)
                    .background(.white)
                    .clipShape(RoundedRectangle(cornerRadius: 5))
                    
                    Button {
                        handleAction()
                    } label: {
                        HStack {
                            Spacer()
                            Text(isLoginMode ? "Đăng nhập" : "Tạo tài khoản")
                                .foregroundColor(.white)
                                .padding(.vertical, 10)
                                .font(.system(size: 14, weight: .semibold))
                            Spacer()
                        }
                        .background(.orange)
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                    }
                    
                    Text(self.loginStatusMessage)
                        .foregroundColor(.red)
                }
                .padding()
            }
            .navigationTitle(isLoginMode ? "Đăng nhập" : "Tạo tài khoản")
            .background(Color(.init(white: 0, alpha: 0.05)) .ignoresSafeArea())
        }
        .navigationViewStyle(StackNavigationViewStyle())
        .fullScreenCover(isPresented: $shouldShowImagePicker, onDismiss: nil) {
            ImagePicker(image: $image)
        }
    }
    
    @State var image: UIImage?
    
    private func handleAction() {
        if isLoginMode {
            loginUser()
            //print("Should log into Firebase with existing credentials")
        }
        else {
            createNewAccount()
            //print("Register")
        }
    }
    
    private func loginUser() {
        FirebaseManager.shared.auth.signIn(withEmail: email, password: password) {
            result, err in
            if let err = err {
                print("Dang nhap bi loi:", err)
                self.loginStatusMessage = " Đăng nhập bị lỗi: \(err)"
                return
            }
            
            print("Dang nhap thanh cong: \(result?.user.uid ?? "")")
            
            self.loginStatusMessage = "Đăng nhập thành công: \(result?.user.uid ?? "")"
            
            self.didCompleteLoginProcess()
        }
    }
    
    @State var loginStatusMessage = ""
    
    private func createNewAccount() {
        if self.image == nil {
            self.loginStatusMessage = "You must select an avatar image"
            return
        }
        
        FirebaseManager.shared.auth.createUser(withEmail: email, password: password) { result, err in
            if let err = err {
                print("Tao user that bat:", err)
                self.loginStatusMessage = "Không thể tạo tài khoản: \(err)"
                return
            }
            
            print("Tao user thanh cong: \(result?.user.uid ?? "")")
            
            self.loginStatusMessage = "Tạo tài khoản thành công: \(result?.user.uid ?? "")"
            
            self.persistImageToStorage()
        }
    }
    
    private func persistImageToStorage() {
        //let filename = UUID().uuidString
        guard let uid = FirebaseManager.shared.auth.currentUser?.uid
            else { return }
        let ref = FirebaseManager.shared.storage.reference(withPath: uid)
        guard let imageData = self.image?.jpegData(compressionQuality: 0.5) else { return }
        ref.putData(imageData, metadata: nil) { metadata, err in
            if let err = err {
                self.loginStatusMessage = "Quá trình upload ảnh lên Storage bị lỗi: \(err)"
                return
            }
            
            ref.downloadURL { url, err in
                if let err = err {
                    self.loginStatusMessage = "Không thể truy xuất tệp tải xuống: \(err)"
                    return
                }
                
                self.loginStatusMessage = "Đã lưu trữ thành công hình ảnh bằng url: \(url?.absoluteString ?? "")"
                print(url?.absoluteString)
                
                guard let url = url else { return }
                self.storeUserInformation(imageProfileUrl: url)
            }
        }
    }
    
    private func storeUserInformation(imageProfileUrl: URL) {
        guard let uid = FirebaseManager.shared.auth.currentUser?.uid else { return }
        let userData = ["email": self.email, "uid": uid, "profileImageUrl": imageProfileUrl.absoluteString]
        FirebaseManager.shared.firestore.collection("users")
            .document(uid).setData(userData) { err in
                if let err = err {
                    print(err)
                    self.loginStatusMessage = "\(err)"
                    return
                }
                
                self.didCompleteLoginProcess()
            }
    }
}

struct LoginView_Previews: PreviewProvider {
    static var previews: some View {
        LoginView(didCompleteLoginProcess: {
            
        })
    }
}
