//
//  RegisterView.swift
//  SocialMedia
//
//  Created by Jose Garcia on 2/6/25.
//

import SwiftUI
import FirebaseAuth
import FirebaseFirestore
import FirebaseStorage
import PhotosUI 

// MARK: Register View
struct RegisterView: View {
    // MARK: User Details
    @State var emailID: String = ""
    @State var password: String = ""
    @State var username: String = ""
    @State var userBio: String = ""
    @State var userBioLink: String = ""
    @State var userProfilePicData: Data?
    // MARK: View Properties
    @Environment(\.dismiss) var dismiss
    @State var showImagePicker: Bool = false
    @State var photoItem: PhotosPickerItem?
    @State var showError: Bool = false
    @State var errorMessage: String = ""
    @State var isLoading: Bool = false
    // MARK: User Defaults
    @AppStorage("log_status") var logStatus: Bool = false
    @AppStorage("user_profile_url") var profileURL: URL?
    @AppStorage("user_name") var usernameStored: String = ""
    @AppStorage("user_UID") var userUID: String = ""
    var body: some View {
        VStack(spacing: 10) {
            Text("Let's Register\nAccount")
                .font(.largeTitle.bold())
                .hAlign(.leading)
            
            Text("Hello user, have a wonderful journey")
                .font(.title3)
                .hAlign(.leading)
            
            // MARK: For Smaller Size Optimization
            ViewThatFits {
                ScrollView(.vertical, showsIndicators: false) {
                    HelperView()
                }
                
                HelperView()
            }
            
            // MARK: Register Button
            HStack {
                Text("Already Have An Account?")
                    .foregroundStyle(.gray)
                
                Button("Sign In Now") {
                    dismiss()
                }
                .fontWeight(.bold)
                .foregroundStyle(.black)
            }
            .font(.callout)
            .vAlign(.bottom)
        }
        .vAlign(.top)
        .padding(15)
        .overlay(content: {
            LoadingView(show: $isLoading)
        })
        .photosPicker(isPresented: $showImagePicker, selection: $photoItem)
        .onChange(of: photoItem, { oldValue, newValue in
            // MARK: Extracting UIImage From PhotoItem
            if let newValue {
                Task {
                    do {
                        guard let imageData = try await newValue.loadTransferable(type: Data.self) else { return }
                        // MARK: UI Must Be Updated On Main Thread
                        await MainActor.run(body: {
                            userProfilePicData = imageData
                        })
                    } catch {
                        
                    }
                }
            }
        })
        // MARK: Displaying Alert
        .alert(errorMessage, isPresented: $showError, actions: {})
    }
    
    @ViewBuilder
    func HelperView() -> some View {
        VStack(spacing: 12) {
            ZStack {
                if let userProfilePicData, let image = UIImage(data: userProfilePicData) {
                    Image(uiImage: image)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                } else {
                    Image("NullProfile")
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                }
            }
            .frame(width: 85, height: 85)
            .clipShape(Circle())
            .contentShape(Circle())
            .onTapGesture {
                showImagePicker.toggle()
            }
            .padding(.top, 25)
            
            TextField("Username", text: $username)
                .textContentType(.username)
                .border(1, .gray.opacity(0.5))
            
            TextField("Email", text: $emailID)
                .textContentType(.emailAddress)
                .border(1, .gray.opacity(0.5))
            
            SecureField("Password", text: $password)
                .textContentType(.password)
                .border(1, .gray.opacity(0.5))
            
            TextField("About You", text: $userBio, axis: .vertical)
                .frame(minHeight: 100, alignment: .top)
                .textContentType(.emailAddress)
                .border(1, .gray.opacity(0.5))
            
            TextField("Bio Link (Optional)", text: $userBioLink)
                .textContentType(.emailAddress)
                .border(1, .gray.opacity(0.5))
            
            Button {
                registerUser()
            } label: {
                // MARK: Sign Up Button
                Text("Sign Up")
                    .foregroundStyle(.white)
                    .hAlign(.center)
                    .fillView(.black)
            }
            .disableWithOpacity(username == "" || userBio == "" || emailID == "" || password == "" || userProfilePicData == nil)
            .padding(.top, 10)
        }
    }
    
    func registerUser() {
        isLoading = true
        closeKeyboard()
        Task {
            do {
                // Step 1: Creating Firebase Account
                try await Auth.auth().createUser(withEmail: emailID, password: password)
                // Step 2: Uploading Profile Photo Into Firebase Storage
                guard let userUID = Auth.auth().currentUser?.uid else { return }
                guard let imageData = userProfilePicData else { return }
                let storageRef = Storage.storage().reference().child("Profile_Images").child(userUID)
                let _ = try await storageRef.putDataAsync(imageData)
                // Step 3: Downloading Photo URL
                let downloadURL = try await storageRef.downloadURL()
                // Step 4: Create a User Firestore Object
                let user = User(username: username, userBio: userBio, userBioLink: userBioLink, userUID: userUID, userEmail: emailID, userProfilePictureURL: downloadURL)
                // Step 5: Saving User Doc into Firestore Database
                let _ = try Firestore.firestore().collection("Users").document(userUID).setData(from: user, completion: { error in
                    if error == nil {
                        // MARK: Print Saved Successfully
                        print("Saved Successfully")
                        usernameStored = username
                        self.userUID = userUID
                        profileURL = downloadURL
                        logStatus = true
                    }
                })
            } catch {
                // MARK: Deleting Created Account In Case of Failure
                //try await Auth.auth().currentUser?.delete()
                await setError(error)
            }
        }
    }
    
    // MARK: Displaying Errors Via Alert
    func setError(_ error: Error) async {
        // MARK: UI Must Be Updated On Main Thread
        await MainActor.run(body: {
            errorMessage = error.localizedDescription
            showError.toggle()
            isLoading = false
        })
    }
}


#Preview {
    RegisterView()
}
