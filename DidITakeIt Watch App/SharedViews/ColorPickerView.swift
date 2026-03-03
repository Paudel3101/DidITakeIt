import SwiftUI

struct ColorPickerView: View {
    @Environment(\.dismiss) var dismiss
    @Binding var selectedColor: String
    
    let colors: [String] = ["blue", "red", "green", "orange", "purple", "pink", "yellow", "cyan"]
    
    var body: some View {
        VStack(spacing: 20) {
            Text("Choose Color")
                .font(.title2)
                .fontWeight(.bold)
            
            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 4), spacing: 15) {
                ForEach(colors, id: \.self) { color in
                    ZStack {
                        Circle()
                            .fill(getColor(color))
                            .frame(height: 60)
                        
                        if selectedColor == color {
                            Circle()
                                .strokeBorder(Color.white, lineWidth: 3)
                                .frame(height: 60)
                                .overlay(
                                    Image(systemName: "checkmark")
                                        .font(.system(size: 20, weight: .bold))
                                        .foregroundColor(.white)
                                )
                        }
                    }
                    .onTapGesture {
                        selectedColor = color
                        dismiss()
                    }
                }
            }
            
            Spacer()
        }
        .padding()
    }
    
    private func getColor(_ colorName: String) -> Color {
        switch colorName {
        case "red": return .red
        case "green": return .green
        case "orange": return .orange
        case "purple": return .purple
        case "pink": return .pink
        case "yellow": return .yellow
        case "cyan": return .cyan
        default: return .blue
        }
    }
}
